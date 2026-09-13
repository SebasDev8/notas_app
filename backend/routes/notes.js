const express = require('express');
const pool = require('../config/database');
const verificarToken = require('../middleware/auth');

const router = express.Router();


//*tener notas
router.get('/', verificarToken, async (req, res) => {
    try {
        const [notes] = await pool.query(
            `SELECT id, title, content, created_at, updated_at
             FROM notes
             WHERE user_id = ?
             ORDER BY updated_at DESC`,
            [req.user.id]
        );

        res.json(notes);

    } catch (error) {
        console.error(error);

        res.status(500).json({
            mensaje: 'Error al obtener las notas'
        });
    }
});


//*Crear la nota
router.post('/', verificarToken, async (req, res) => {
    try {
        const { title, content } = req.body;

        if (!title || !content) {
            return res.status(400).json({
                mensaje: 'El título y el contenido son obligatorios'
            });
        }

        const [result] = await pool.query(
            `INSERT INTO notes (user_id, title, content)
             VALUES (?, ?, ?)`,
            [
                req.user.id,
                title,
                content
            ]
        );

        const [notes] = await pool.query(
            `SELECT id, title, content, created_at, updated_at
             FROM notes
             WHERE id = ? AND user_id = ?`,
            [
                result.insertId,
                req.user.id
            ]
        );

        res.status(201).json({
            mensaje: 'Nota creada correctamente',
            nota: notes[0]
        });

    } catch (error) {
        console.error(error);

        res.status(500).json({
            mensaje: 'Error al crear la nota'
        });
    }
});


//*actualizar
router.put('/:id', verificarToken, async (req, res) => {
    try {
        const { title, content } = req.body;
        const noteId = req.params.id;

        if (!title || !content) {
            return res.status(400).json({
                mensaje: 'El título y el contenido son obligatorios'
            });
        }

        const [result] = await pool.query(
            `UPDATE notes
             SET title = ?, content = ?
             WHERE id = ? AND user_id = ?`,
            [
                title,
                content,
                noteId,
                req.user.id
            ]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                mensaje: 'Nota no encontrada'
            });
        }

        const [notes] = await pool.query(
            `SELECT id, title, content, created_at, updated_at
             FROM notes
             WHERE id = ? AND user_id = ?`,
            [
                noteId,
                req.user.id
            ]
        );

        res.json({
            mensaje: 'Nota actualizada correctamente',
            nota: notes[0]
        });

    } catch (error) {
        console.error(error);

        res.status(500).json({
            mensaje: 'Error al actualizar la nota'
        });
    }
});


//*eliminar
router.delete('/:id', verificarToken, async (req, res) => {
    try {
        const noteId = req.params.id;

        const [result] = await pool.query(
            `DELETE FROM notes
             WHERE id = ? AND user_id = ?`,
            [
                noteId,
                req.user.id
            ]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                mensaje: 'Nota no encontrada'
            });
        }

        res.json({
            mensaje: 'Nota eliminada correctamente'
        });

    } catch (error) {
        console.error(error);

        res.status(500).json({
            mensaje: 'Error al eliminar la nota'
        });
    }
});


module.exports = router;