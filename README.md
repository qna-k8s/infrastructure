# Infrastructure As Code
**IACC to setup:**
   - EKS cluster
   - VPC, Subnets and Security Groups
   
**Instructions:** 
- Set AWS_PROFILE environment variable  
`export AWS_PROFILE=profile_name`  
- Initialize Terraform  
`terraform init`  
- Validate template  
`terraform validate`  
- Make an execution plan  
`terraform plan`  
- Create Resources  
`terraform apply`  
- Destroy Resources  
`terraform destory`