const express = require('express');
const AWS = require('aws-sdk');
const bodyParser = require('body-parser');
const path = require('path');
require('dotenv').config();

// Configure AWS SDK
AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const dynamodb = new AWS.DynamoDB.DocumentClient();
const sns = new AWS.SNS();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'build')));

// Get all deals
app.get('/api/deals', async (req, res) => {
  try {
    // Assuming your DynamoDB table name is stored in environment variables
    const tableName = process.env.DEALS_TABLE_NAME;
    
    const params = {
      TableName: tableName,
      // You might want to limit the number of results or filter by date
      Limit: 50
    };
    
    const result = await dynamodb.scan(params).promise();
    res.json(result.Items);
  } catch (error) {
    console.error('Failed to fetch deals:', error);
    res.status(500).json({ error: 'Failed to fetch deals' });
  }
});

// Subscribe to notifications
app.post('/api/subscribe', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }
    
    // Create a topic if it doesn't exist or use an existing topic
    const topicArn = process.env.SNS_TOPIC_ARN;
    
    // Subscribe email to the topic
    const subscribeParams = {
      Protocol: 'email',
      TopicArn: topicArn,
      Endpoint: email
    };
    
    await sns.subscribe(subscribeParams).promise();
    
    // Optionally store subscriber info in DynamoDB
    const subscribersTable = process.env.SUBSCRIBERS_TABLE_NAME;
    if (subscribersTable) {
      const params = {
        TableName: subscribersTable,
        Item: {
          email,
          subscribedAt: new Date().toISOString()
        }
      };
      
      await dynamodb.put(params).promise();
    }
    
    res.status(200).json({ message: 'Subscription successful. Please check your email to confirm.' });
  } catch (error) {
    console.error('Subscription failed:', error);
    res.status(500).json({ error: 'Failed to subscribe' });
  }
});

// Unsubscribe from notifications
app.post('/api/unsubscribe', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }
    
    // Find subscription by email
    const topicArn = process.env.SNS_TOPIC_ARN;
    const listParams = {
      TopicArn: topicArn
    };
    
    const subscriptions = await sns.listSubscriptionsByTopic(listParams).promise();
    const subscription = subscriptions.Subscriptions.find(sub => sub.Endpoint === email);
    
    if (subscription) {
      // Unsubscribe
      await sns.unsubscribe({ SubscriptionArn: subscription.SubscriptionArn }).promise();
    }
    
    // Remove from DynamoDB if you're storing subscribers
    const subscribersTable = process.env.SUBSCRIBERS_TABLE_NAME;
    if (subscribersTable) {
      const params = {
        TableName: subscribersTable,
        Key: { email }
      };
      
      await dynamodb.delete(params).promise();
    }
    
    res.status(200).json({ message: 'Unsubscribed successfully' });
  } catch (error) {
    console.error('Unsubscribe failed:', error);
    res.status(500).json({ error: 'Failed to unsubscribe' });
  }
});

// Serve React app for any other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});