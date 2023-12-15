const express = require('express');
const http = require('http');
const mongoose  = require('mongoose');
const authRouter = require('./routes/authRoute');
const cors = require('cors');
const documentRouter = require('./routes/documentRoute');
const Document = require('./models/documentModel');


const PORT = process.env.PORT | 3001;

const app = express();
var server = http.createServer(app);
var io = require('socket.io')(server);

app.use(cors());
app.use(express.json())
app.use(authRouter)
app.use(documentRouter)

const DB= "mongodb+srv://abhayajeet02:abhayapadhi02@cluster0.d4l7glv.mongodb.net/?retryWrites=true&w=majority";

mongoose.connect(DB).then(() => {
    console.log('Connection successful!');
}).catch((err) => {
    console.log(err);
})

io.on('connection', (socket) => {
    socket.on('join', (documentId) => {
        socket.join(documentId);
        console.log('joined');
    })

    socket.on('typing', (data) => {
        socket.broadcast.to(data.room).emit('changes',data);
    })

    socket.on('save', (data) => {
        saveData(data);
    })
})

const saveData = async(data) => {
    let document = await Document.findById(data.room);
    document.content = data.delta;
    document = await document.save();
}

server.listen(PORT , '0.0.0.0', () => {
    console.log(`Connected at ${PORT}`);
})

