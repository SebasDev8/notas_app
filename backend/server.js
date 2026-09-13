const express = require('express');
const cors = require('cors');
const pool = require('./config/database');
const authRoutes = require('./routes/auth');
const notesRoutes = require('./routes/notes');

const app = express();

app.use(cors());

app.use(express.json());

app.use('/api/auth', authRoutes);

app.use('/api/notes', notesRoutes);

app.get('/', (req, res) => {
    res.json({
        mensaje: 'API funcionando'
    });
});

app.get('/test-db', async (req, res) => {
    try {
        const [rows] = await pool.query('SELECT 1 AS resultado');

        res.json({
            mensaje: 'Conexión con MySQL',
            resultado: rows[0].resultado
        });
    } catch (error) {
        console.error(error);

        res.status(500).json({
            mensaje: 'Error con MySQL'
        });
    }
});

const PORT = 3000;

app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});