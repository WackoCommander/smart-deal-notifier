#!/bin/bash

cd lambda
rm -rf package
mkdir package

# Install dependencies to the 'package' directory
pip install -r requirements.txt -t package

# Copy all the necessary files into the 'package' directory
cp *.py package/

# Create a ZIP file to deploy
cd package
zip -r ../lambda_package.zip .
cd ..

