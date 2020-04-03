---
title: "Using AWS Cloudwatch Insights"
author: ""
type: ""
date: 2020-04-03T02:52:16-04:00
subtitle: "To find the biggest users of NAT Gateway"
image: ""
tags: ["aws", "cloudwatch", "cost analysis"]
---

## Unexpected Costs
If there is one thing I've learned from using AWS for the last few years, it's that there always seems to be high spend from unexpected sources. Recently, my company decided to put a concerted effort into reducing it's AWS spend. There were definitely obvious areas to reduce cost (e.g. right sizing), but there were was one cost that I found particulary interesting, a service named `EC2-Other`. Initially, I had no idea what resources would fall under this service, it turned out to be a variety of things. Using `Cost Explorer`, I was able to breakdown the cost to a more granular level with `Usage Type Group`. Eventually, I was able to pinpoint the largest contributor: `EC2: NAT Gateway - Data Processed`.

### What is NAT Gateway?
`NAT Gateway` is a managed AWS service that allows private resources in a VPC to connect to internet resources. There are two costs that you need to be aware of for [NAT Gateway](https://aws.amazon.com/vpc/pricing/):

* Running Hours: Hourly operating cost of $0.045 per hour
* Data Usage: $0.045 per GB data processed

## Identifying Internet Destinations
By default, `NAT Gateway` is only allowing egress traffic to the internet. So I needed to find a way to determine what were the top internet destinations by bandwidth. The easiest way to get this information is to first enable Flow Logs at the VPC level.

### Enable VPC Flow Logs
{{< gallery caption-effect="fade" >}}
  {{< figure thumb="-thumb" link="/images/aws-vpc-flow-log.png" caption="Enable VPC Flow Logs" >}}
{{< /gallery >}}

Flow logs capture information about the IP traffic going to and from your network interfaces (ENI) in your VPC. Although in my example the capture is set at the VPC level, you can also enable logging at the individual network interface level.

When you enable flow logging, you'll have a choice of two destinations: `s3` or `CloudWatch Logs`. I chose `CloudWatch Logs` because I wanted to use another tool called `CloudWatch Insights` to analyze the data.

### What is CloudWatch Insights?
[CloudWatch Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html) is a tool that allows you to interactively search and analyze your log data in CloudWatch logs. It has a fairly simple query language and automatically discovers available fields to filter on from the logs.

### NAT Gateway Query
I needed two things before I could construct the query:

* NAT Gateway private IP address: You can look it up at `VPC Dashboard > NAT Gateways`
* Private Subnet CIDR's

With that information, my query looked something like this:

{{< highlight javascript >}}
    filter ((srcAddr like 'Your NAT Gateway IP') and dstAddr not like 'Private Subnet' )
    | stats sum(bytes) as bytesTransferred by srcAddr, dstAddr
    | sort bytesTransferred desc
    | limit 20
{{</ highlight >}}

This query was filtered where the source ip address is the `NAT Gateway` and the destination wouldn't include traffic from the private subnet. In otherwords, we're only interested in internet addresses. Other than ip address, the field that we are interested in is `bytesTransferred`. This field will be aggregated and used to give the top 20 internet destinations by bandwith processed.

### Analyzing the Query
I set the length of the query to go back a month so that I could match it up with the `GB Data Processed` metric from `Cost Explorer`. After running the query, the results were pretty interesting. 19 out of the top 20 results started with `52.216` or `52.217`. I had a suspicion that these were public AWS addresses. There is a [public endpoint](https://ip-ranges.amazonaws.com/ip-ranges.json) that provides a JSON object with this information. It even associates AWS services to each IP range.

It turns out that those 19 addresses were all `AWS S3`! That was surprising to me because I figured that private resources would automatically stay within the private AWS network to connect to `S3`. Apparently that was a bad assumption.

### Optimizing Routes to S3
Luckily, there is a simple way to optimize private traffic routes to `S3`: [VPC Endpoints for S3](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints-s3.html). To enable, all you have to do is select the VPC route tables where you want this in effect. Once enabled, you'll notice a new route added near the top of the route table. The route basically says that any traffic that is destined for the public s3 endpoints will now be directed to the VPC Endpoint, effectively keeping the traffic within the private AWS networks.

## Conclusion
After waiting for several days, I used `Cost Explorer` to compare the daily costs of `EC2 - Other` before and after the change. Our daily spend was reduced by a whopping 80%! It was pretty crazy how the implementation only took a few of minutes (using Terraform) and the immediate financial impact of that quick change. It was a great experience to better understand how costs are broken down, that data transfers costs need to be considered when evaluating the cost of an AWS service, and how to utilize the tools readily available in the AWS ecosystem to perform network analysis.