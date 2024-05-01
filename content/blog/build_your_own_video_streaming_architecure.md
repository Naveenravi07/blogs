+++
title = "Build your own video streaming architecture and save yourselves from getting broke"
date =2024-05-01 
taxonomies.tags = [
    "Personal",
]
taxonomies.categories = [
    "Personal"
]
+++

Hey everyone,

I'm thrilled to share a recent milestone in my personal project journey:
completing a significant aspect of my video processing infrastructure. I've
always been fascinated by the mechanics behind platforms like YouTube, which
seamlessly process video files into multiple qualities in a highly scalable
manner. While AWS MediaConvert is a popular choice for this task, I've
discovered a cost-effective alternative that I'm excited to share with you.
Let's delve into the architecture of my implementation

Note : In the below diagram there are some basic steps which i dont include in this blog.
Like creation of preSignedUrl and all as the primary goal of this blog is to
share the core concepts. So lets dive in

<img src="https://theshastri.s3.us-west-1.amazonaws.com/videostreamingarchitecture.png" />

    1) Uploading Process: When a user uploads a video, the file is stored in a
    development S3 bucket.

    2) Event Handling: Within the S3 environment, we set up event listeners to
    track actions like uploads. Upon each upload event, metadata from the S3
    request is added to an SQS queue. Once the queue reaches a certain
    threshold, a Lambda function is triggered. This queue mechanism ensures
    robustness in handling events, especially in case of errors during Lambda
    execution.

    3) The Lambda Function: This function plays a crucial role in orchestrating the
    video processing workflow. It initiates a spot EC2 instance remotely and
    communicates instructions to it. Leveraging spot instances for video
    processing can significantly reduce costs, particularly for
    non-time-sensitive tasks like video transcoding. However, it's important to
    consider instance availability and potential interruptions.

    4)Processing Instructions: Instructions passed to the EC2 instance typically
    involve a shell script. This script downloads the video from the development
    bucket and utilizes FFmpeg, a versatile tool for video processing. FFmpeg is
    employed to transcode the video into HLS (HTTP Live Streaming) compatible
    streams of varying qualities. The processed video is then uploaded to a
    production S3 bucket.

    5) Content Delivery Network (CDN): To ensure optimal delivery speed, HLS
    streams are served from a CDN rather than directly from the production
    bucket. A CDN is a network of distributed proxy servers and data centers
    strategically positioned to minimize latency and maximize performance for
    end-users

This setup forms the backbone of my video processing infrastructure. I'm eagerly
anticipating its performance and look forward to further enhancements. In the
pipeline, I plan to integrate additional features such as subtitle generation to
enrich the viewing experience. Stay tuned for updates as this project evolves!

