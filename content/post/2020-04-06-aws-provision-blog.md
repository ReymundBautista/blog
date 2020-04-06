---
title: How I provisioned this blog with AWS
date: 2020-04-06T00:15:51-04:00
tags: ["aws", "cloudfront", "lambda", "lambda@edge", "s3"]
---

{{< gallery caption-effect="fade" >}}
  {{< figure thumb="-thumb" link="/images/clouds.jpg" caption="AWS Computing Visualized" >}}
  {{< figure thumb="-thumb" link="/images/clouds2.jpg" caption="AWS Computing Visualized" >}}
  {{< figure thumb="-thumb" link="/images/clouds3.jpg" caption="AWS Computing Visualized" >}}
{{< /gallery >}}

I've been using AWS for several years now so I figured that it would only be 
appropriate if I provisioned this blog on AWS infrastructure. So why I am 
writing about this? Well it's not to focus on the services themselves, but 
rather to highlight some of the struggles I faced and some requirements that 
I wasn't aware of.

<!--more-->
## Design Considerations
There were a few considerations that dictated which services I would end up
using:

1. My site will be static
2. Traffic must be SSL/TLS
3. Keep costs as low as possible
4. Resiliency and uptime isn't important

## The Infrastructure
With those design consideration in mind, these were the services that I 
initially decided to work with:

* S3
* CloudFront
* ACM

### S3
Perfect for hosting a static web site for a really attractive price. 
Since this was a static site that could be regenerated at anytime, resiliency 
wasn't a consideration. And since I was looking for a cost-effective solution, 
`One Zone-IA` was the perfect storage class. The interesting thing I learned was 
that you can't set a S3 bucket to a specific storage class. From the bucket 
side, all you can do is set a `Lifecycle` transition policy. The gotcha, however, 
is that the minimum time you must set is 30 days. This means that you 
need to ensure that your client that pushes the objects to S3 must 
explicitly set the storage class.

Another interesting thing was that I didn't have to make the bucket public. This
meant users would not be able to bypass CloudFront and access S3 directly.
This ensures that we maximize the benefits of using a CDN and minimize data 
transfer costs. This configuration, however, would later cause an unexpected 
issue with CloudFront which I will explain later.  

### CloudFront
To satisfy my requirement of encrypting traffic with SSL/TLS, CloudFront was
the logical choice. Additionally, as a CDN, it's perfect for a static site.
One feature in particular that I found interesting was the `Origin Access 
Identity` (OAI). This identity can be configured with a CloudFront distribution 
and can have IAM Permissions assigned to it in a S3 bucket policy.

If you use OAI, then the S3 bucket must **not** be configured in static website 
mode which means that the bucket can be private. Secondly, when you provide the
origin URL, it must be in the S3 REST API endpoint format:
    
_`s3-bucket-name`_.s3._`aws-region`_.amazonaws.com

### ACM
A couple of things of note. First, the certificate must be generated in
`us-east-1` in order to be accessible by CloudFront. Secondly, if you are using 
an infrastructure-as-code tool like `Terraform`, you will have to provision the
certificate manually due to some manual requirements.

## Easy Right?
The front page loaded so we're good? Not so fast. When I tried to browse to one 
of the posts, I ended up getting a **404 NoSuchKey** error. After messing around
for awhile, I discovered that I could access the posts if I explicity added
`index.html` to the end of the URL. With this info I was able to find an [AWS 
article](https://aws.amazon.com/blogs/compute/implementing-default-directory-indexes-in-amazon-s3-backed-amazon-cloudfront-origins-using-lambdaedge/)
explaining why the `default directory indexes` wasn't active. As I mentioned
earlier, because I was using OAI, the S3 static site feature needed to be disabled.
This also meant that `default directoy indexes` aren't enabled either. 
Fortunately, the article provided a workaround even though it ended up being a
bit of a hassle to implement.

### Lambda@Edge
To workaround the issue, you can use `Lambda@Edge` which allows you to use a
Lambda function with CloudFront. Since CloudFront only has so many capabilities,
you can use [Lambda@Edge](https://aws.amazon.com/lambda/edge/) to further 
optimize and enhance the performance of your web applications. In my case, I 
needed it to rewrite the origin URL's to ensure that `index.html` was appended 
to the end of all URL slugs. 

For example, _domain/posts/topic/_ would be rewritten as 
_domain/posts/topic/index.html_.

### Implementing Lambda@Edge
You set it up just like a normal Lambda function, but there are a couple of 
things to note:

1. It must be provisioned in the `us-east-1` region in order to be triggered by
CloudFront. Once triggered, CloudFront will replicate the Lambda function 
to edge locations.
1. When it is assigned to a [Cache Behavior](https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_CacheBehavior.html)
, you must provide the Lambda ARN with the specific version:

    `arn:aws:lambda:us-east-1:123456789012:function:TestFunction:2`

### Test your code!
The AWS article also provided a sample Node script that you could use to perform the 
rewrites. Little did I know that I made a copypasta mistake and accidentally
left out the first character. This ends up being a painfully slow process to 
troubleshoot because if you've ever iterated with CloudFront, you'll know that 
changes usually take 5-10 minutes to replicate. As I was running out of options, 
I eventually ran this command to test the syntax of a Node script:

```bash
    $ node --check index.js
```

This check revealed that I had left out a single quote mark. SMH.

## Conclusion
This is actually a fairly simple setup now that I've learned my lessons. Like a
good DevOps practicioner, I used `Terraform` to provision my infrastructure. If
you want to see the gory details, check out my Terraform module on 
[Github](https://github.com/ReymundBautista/terraform-aws-blog). I'll update 
this post in about a month with a cost breakdown.