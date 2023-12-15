const express = require('express');
const Document = require('../models/documentModel');
const authMiddle = require('../middleware/authMiddleware');

const documentRouter = express.Router();

documentRouter.post('/doc/create' , authMiddle, async(req,res) => {
    try {
        const {createdAt} = req.body
        let document = new Document({
            uid : req.user,
            title : 'Untitled Document',
            createdAt,
        })

        document = await document.save();
        res.json(document);
    } catch (e) {
        res.status(500).json({error : e.message});
    }
});

documentRouter.get('/docs/me', authMiddle, async(req,res) => {
    try {
        let docs = await Document.find({uid : req.user});
        res.json(docs);
    } catch (e) {
        res.status(500).json({error : e.message});
    }
});

documentRouter.post('/doc/title' , authMiddle, async(req,res) => {
    try {
        const {id,title} = req.body
        const document = await Document.findByIdAndUpdate(id, {title})

        res.json(document);
    } catch (e) {
        res.status(500).json({error : e.message});
    }
});

documentRouter.get('/doc/:id', authMiddle, async(req,res) => {
    try {
        const doc = await Document.findById(req.params.id);
        res.json(doc);
    } catch (e) {
        res.status(500).json({error : e.message});
    }
});

module.exports = documentRouter;