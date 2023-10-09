# bootcamp-terraform

# Manual steps:

- Push code to codecommit to trigger pipeline after terraform created the resources.

- Create aws-auth for the assume role that are being use for EKS (`$EKS_ROLE_ARN` in `api-buildspec.yml`). Refer to this link: https://stackoverflow.com/questions/50791303/kubectl-error-you-must-be-logged-in-to-the-server-unauthorized-when-accessing

- Create secret for EKS cluster using this command (replace ${variable} with actual value):

`kubectl create secret generic mysecret \
                --from-literal=DB_HOST=${DB_HOST} \
                --from-literal=DB_PASSWORD=${DB_PASSWORD} \
                --from-literal=DB_USERNAME=${DB_USERNAME} \
                --from-literal=DB_NAME=${DB_NAME}`

- We are using S3 static website hosting so we have to manually update the backend endpoint in code and push the changes to codecommit (s3 doesn't support dynamic value for static web hosting)
