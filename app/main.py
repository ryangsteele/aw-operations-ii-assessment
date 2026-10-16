"""Shortlink: a tiny URL shortener backed by S3, configured from SSM.

On startup the service reads one SSM parameter (CONFIG_SSM_PATH) to learn
which S3 bucket to store links in. If that parameter cannot be read the
service exits immediately: running without config would only hide the
problem until the first request.
"""

from __future__ import annotations

import logging
import os
import secrets
import sys

import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, HttpUrl

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger('shortlink')


def load_config() -> tuple[str, 'boto3.client']:
    endpoint = os.environ.get('AWS_ENDPOINT_URL')
    param_path = os.environ.get('CONFIG_SSM_PATH')
    if not param_path:
        log.error('CONFIG_SSM_PATH is not set; refusing to start')
        sys.exit(1)

    ssm = boto3.client('ssm', endpoint_url=endpoint)
    try:
        response = ssm.get_parameter(Name=param_path)
    except ClientError as exc:
        log.error('could not read config parameter %r: %s', param_path, exc)
        sys.exit(1)

    bucket = response['Parameter']['Value']
    log.info('configured with bucket %r (from %s)', bucket, param_path)
    return bucket, boto3.client('s3', endpoint_url=endpoint)


BUCKET, s3 = load_config()

api = FastAPI(title='shortlink')


class LinkRequest(BaseModel):
    url: HttpUrl


@api.get('/healthz')
def healthz() -> dict[str, str]:
    try:
        s3.head_bucket(Bucket=BUCKET)
    except ClientError as exc:
        raise HTTPException(status_code=503, detail=f'cannot reach bucket {BUCKET}: {exc}')
    return {'status': 'ok', 'bucket': BUCKET}


@api.post('/api/links', status_code=201)
def create_link(request: LinkRequest) -> dict[str, str]:
    slug = secrets.token_urlsafe(8)
    s3.put_object(Bucket=BUCKET, Key=slug, Body=str(request.url).encode())
    return {'slug': slug, 'short_url': f'/r/{slug}'}


@api.get('/api/links')
def list_links() -> list[str]:
    paginator = s3.get_paginator('list_objects_v2')
    return [
        obj['Key']
        for page in paginator.paginate(Bucket=BUCKET)
        for obj in page.get('Contents', [])
    ]


@api.get('/r/{slug}')
def redirect(slug: str) -> RedirectResponse:
    try:
        obj = s3.get_object(Bucket=BUCKET, Key=slug)
    except ClientError:
        raise HTTPException(status_code=404, detail=f'no link for slug {slug!r}')
    return RedirectResponse(obj['Body'].read().decode(), status_code=302)
