**Serving a static website from s3 through CloudFront**

Project Introduction  
This AWS project is going to demonstrate the process of serving a website from S3 through a Content Delivery Network known as CloudFront. As I teased in my S3 project, enabling static website hosting in S3 comes with some security risks to the S3 bucket since we disabled the “Block All Public Access” option. Also S3 does not natively support HTTPS, hence all traffic from the bucket to the end user client uses HTTP. In this project, we would be serving the static website from S3 through CloudFront, however using proper Infrastructure-as-Code DevOps practices, we would be doing this entire project with the AWS CLI, AWS CloudFormation and Terraform.

What is CloudFront?  
CloudFront is AWS’s Content Delivery Network. It serves content from an Origin (such as S3) through a location closer to the end user. It uses a series of edge locations all around the world which are used to cache data from the Origin server(in this case S3). This reduces the load on the Origin and the costs associated with data retrieval from the origin upon reloads and subsequent visits. CloudFront is also convenient for this project because it supports HTTPS and with CloudFront Origin Access Control(OAC), CloudFront can access the content of the S3 bucket without having to enable static website hosting or disabling the “Block all Public Access ” option on the bucket.

What is CloudFormation?  
CloudFormation is AWS’s native infrastructure-as-code(IAC) service. You can describe the AWS resources to be created in a file called a template. It can be written in YAML or JSON. I would highly suggest learning cloudformation if you plan to be an AWS Devops Engineer.

What is Terraform?  
Terraform is also another Infrastructure-as-code service, however it is owned by Hashicorp not AWS. The main appeal behind Terraform is that it is a cross platform service. It supports AWS, Google Cloud, Ms Azure, Kubernetes, Docker, Auth0 etc.

Services Used
- S3
- CloudFormation
- CloudFront
- Terraform
- AWS CLI

The Project  
The CloudFormation Template I created for this project would be provided in this Github repo. I also created a terraform file for this project which would be in this repository. I'll be explaining the CloudFormation template used in this project.  
The resources section contains all the AWS resources to be created by CloudFormation.

- An S3 bucket called “movie-project-bucket will be created” with versioning enabled.
- An Origin Access Control named “S3AccessControl” would be created to be used by the CloudFront Distribution. This would allow the CloudFront Distribution to access the content of the S3 bucket while “Block all Public Access” is still on.

![](./images/image6)

- A CloudFront Distribution would be created and it would be enabled upon creation. The Origin would be the S3 bucket created above. All requests would be redirected to HTTPS and the only Methods being cached at the edge locations are GET and HEAD. Since this website is static, we do not need other request types.
- The “DefaultRootObject” is similar to the index document in S3 as it tells CloudFront where to point to in the origin(S3 bucket) upon a request.

![](./images/image12)

- The screenshot below shows the bucket policy for the S3 bucket which would grant the CloudFront Distribution access through OAC.
- It would allow the CloudFront distribution to perform only the “S3:GetObject” action on the bucket.

![](./images/image1)

- The Outputs section is used to give us information about the resources after creation. In this case the Output we are requesting is the url of the CloudFront Distribution. We can view the outputs through the terminal instead of the console.

Now how do we run this template? That's where CloudFormation comes in. We can access CloudFormation through the AWS CLI. In my case I'm using the powershell terminal through VSCode. You can sign in using your account access keys or in my case temporary security credentials.

- Its best practice to validate your YAML template first to catch any syntax errors. To do this you can run: “aws cloudformation validate-template \--template-body file://nameoftemplate.yml” in the directory containing your template file.

![](./images/image10)

- If there are no errors, you can then proceed to deploy the template to CloudFormation using: “aws cloudformation deploy \--template-file nameoftemplate.yml \--stack-name nameofstack”
- A stack would be created by CloudFormation in accordance with the resources in the template

![](./images/image5)

- Now we can go ahead and upload the website files to the S3 bucket using the CLI. You can use the command: “aws s3 cp sourcedirectoryname/ s3://nameofbucket \--recursive” to upload the website files from your local directory to the bucket.
- After the files are uploaded, you can verify the contents of the bucket using the ls command: “aws s3 ls s3://nameofbucket”

![](./images/image11)

- After confirmation that the website files are in the bucket, we can request the Output for the CloudFront distribution URL using the describe-stacks command: “aws cloudformation describe-stacks \--stack-name nameofstack \--query “Stacks\[0\].Outputs””

![](./images/image3)

- After copying the Output Value from the terminal to a browser, the website should display.

![](./images/image7)

- From the Screenshot above, you can observe that the website is being encrypted over HTTPS as shown by the icon on the left next to the website URL.

The resources we created can be viewed in the console.

- The CloudFormation stack from the template

![](./images/image4)

- The S3 bucket created from the template and its contents; the website files.

![](./images/image2)

![](./images/image9)

- The CloudFront distribution created from the template

![](./images/image8)

I have also written a Terraform file for the creation of these same resources if the reader is more comfortable with Terraform in comparison to CloudFormation.

Some Key Notes

1. The problem with bucket vulnerability has been fixed. Since the bucket contents are now being served through a CloudFront distribution using OAC, there is no need to disable the “Block all public access” option or to set the Principal in the bucket policy to “\*”.
2. With HTTPS, web traffic is now encrypted and secure.
3. Due to the caching capabilities of CloudFront, not all requests are loaded from the S3 bucket, but instead the CloudFront edge locations closer to the end user.

Future Plans  
Remember that due to the problem of object storage in s3, with any change made to the website files, an entirely new version of the file must be uploaded to S3. Developers are constantly making changes weekly or daily to web applications. Whether in a live or testing stage, the process of logging in to AWS just to upload a formatted website file to s3 would be tedious, inefficient and with the added risks to the AWS account. That’s where a version control system with a continuous-integration and continuous-delivery(CI/CD) pipeline comes in. In my next project I'll be using Github and AWS CodePipeline to solve these issues.
