const express = require('express');
const admin = require('firebase-admin');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { OpenAI } = require('openai');
const cors = require('cors');
const helmet = require('helmet');

if (!process.env.OPENAI_API_KEY || !process.env.STRIPE_SECRET_KEY) {
  throw new Error('Missing required environment variables: OPENAI_API_KEY and STRIPE_SECRET_KEY');
}

admin.initializeApp();
const db = admin.firestore();
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const app = express();
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

app.get('/healthz', (_req, res) => {
  res.status(200).json({ ok: true, service: 'cafeteria-backend' });
});

// 1. AI Assistant: Budget-aware Menu Suggestions
app.post('/ai-chat', async (req, res) => {
  try {
    const { query, budget, businessId } = req.body;

    if (!query || !budget || !businessId) {
      return res.status(400).json({ error: 'query, budget, and businessId are required.' });
    }

    // Fetch this specific cafeteria's menu
    const menuSnapshot = await db
      .collection('businesses')
      .doc(businessId)
      .collection('products')
      .get();

    const menu = menuSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const prompt = `You are the AI for "${businessId}" Cafeteria.
Menu: ${JSON.stringify(menu)}.
User Budget: $${budget}.
Task: Suggest 2-3 items from the menu that fit the budget. Mention if subtotal + $2 delivery exceeds budget.
User Question: "${query}"`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: 'You are a concise cafeteria assistant. Prioritize budget and provide transparent pricing.',
        },
        { role: 'user', content: prompt },
      ],
      temperature: 0.2,
    });

    return res.json({ answer: completion.choices?.[0]?.message?.content ?? 'No response available.' });
  } catch (error) {
    console.error('/ai-chat error:', error);
    return res.status(500).json({ error: 'Failed to process AI request.' });
  }
});

// 2. Stripe Checkout: Taxes, Delivery, and Branded Invoice
app.post('/create-checkout', async (req, res) => {
  try {
    const { cartItems, businessId, customerEmail } = req.body;

    if (!Array.isArray(cartItems) || cartItems.length === 0 || !businessId || !customerEmail) {
      return res.status(400).json({
        error: 'cartItems (non-empty array), businessId, and customerEmail are required.',
      });
    }

    const lineItems = cartItems.map((item) => ({
      price_data: {
        currency: 'usd',
        product_data: { name: item.name },
        unit_amount: Math.round(Number(item.price) * 100),
      },
      quantity: Number(item.quantity),
    }));

    // Flat delivery fee
    lineItems.push({
      price_data: {
        currency: 'usd',
        product_data: { name: 'Delivery Fee' },
        unit_amount: 200,
      },
      quantity: 1,
    });

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: lineItems,
      mode: 'payment',
      customer_email: customerEmail,
      automatic_tax: { enabled: true },
      shipping_address_collection: { allowed_countries: ['US'] },
      invoice_creation: { enabled: true },
      success_url: `https://${businessId}.web.app/success`,
      cancel_url: `https://${businessId}.web.app/cancel`,
      metadata: { businessId },
    });

    return res.json({ url: session.url });
  } catch (error) {
    console.error('/create-checkout error:', error);
    return res.status(500).json({ error: 'Failed to create checkout session.' });
  }
});


// 3. Stripe Webhook Placeholder (recommended for production order reconciliation)
app.post('/stripe-webhook', (req, res) => {
  // TODO: verify Stripe signature and update order state in Firestore.
  return res.status(501).json({ error: 'Webhook handler not implemented yet.' });
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Backend Live on Port ${port}`));
