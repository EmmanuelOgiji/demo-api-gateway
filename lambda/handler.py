import boto3
import os
import random
from botocore.client import Config

# Force SigV4 for KMS-encrypted objects
s3 = boto3.client('s3', config=Config(signature_version='s3v4'))

BUCKET = os.environ['BUCKET_NAME']
PREFIX = 'images/'  # Your S3 folder (or just "" if none)

def lambda_handler(event, context):
    # 1. Get list of image keys
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX)
    files = [obj['Key'] for obj in response.get('Contents', []) if obj['Key'] != PREFIX]

    if not files:
        return {
            "statusCode": 404,
            "body": "No images found."
        }

    # 2. Pick a random image
    selected = random.choice(files)

    # 3. Generate a presigned URL
    presigned_url = s3.generate_presigned_url(
        ClientMethod='get_object',
        Params={
            'Bucket': BUCKET,
            'Key': selected
        },
        ExpiresIn=300  # 5 minutes
    )

    # 4. Return HTML response with the image
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Random Image</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {{
                text-align: center;
                font-family: sans-serif;
                padding: 2rem;
            }}
            img {{
                max-width: 90vw;
                max-height: 80vh;
                border-radius: 1rem;
                box-shadow: 0 0 20px #ccc;
            }}
            button {{
                margin-top: 1rem;
                padding: 0.5rem 1rem;
                font-size: 1rem;
                border: none;
                border-radius: 0.5rem;
                background: #007acc;
                color: white;
                cursor: pointer;
            }}
        </style>
    </head>
    <body>
        <h1>🎁 A Random Surprise</h1>
        <img src="{presigned_url}" alt="Random Image" />
        <br/>
        <button onclick="window.location.reload()">🔄 Show Another</button>
    </body>
    </html>
    """

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html; charset=utf-8",
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache"
        },
        "body": html
    }
