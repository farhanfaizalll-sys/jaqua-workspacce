import { Router } from 'express';
import { register, login, me, changePassword, logout } from '../controllers/auth.controller';
import { validateBody } from '../middleware/validate.middleware';
import { requireAuth } from '../middleware/auth.middleware';
import { registerSchema, loginSchema, changePasswordSchema } from '../validators/auth.validator';

const router = Router();

router.post('/register', validateBody(registerSchema), register);
router.post('/login', validateBody(loginSchema), login);
router.get('/me', requireAuth, me);
router.post('/change-password', requireAuth, validateBody(changePasswordSchema), changePassword);
router.post('/logout', requireAuth, logout);

export default router;
