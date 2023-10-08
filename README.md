# bootcamp-terraform

# Manual steps:
- Since we can 

- We are using S3 static website hosting so we have to manually update the backend endpoint in code and push the changes to codecommit (s3 doesn't support dynamic value for static web hosting)

kubectl create secret generic mysecret \
                --from-literal=DB_HOST=${DB_HOST} \
                --from-literal=DB_PASSWORD=${DB_PASSWORD} \
                --from-literal=DB_USERNAME=${DB_USERNAME} \
                --from-literal=DB_NAME=${DB_NAME}