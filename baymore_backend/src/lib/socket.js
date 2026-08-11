let ioInstance = null;

function initSocket(io) {
  ioInstance = io;

  io.on('connection', (socket) => {
    // Le client rejoint la room de sa commande pour recevoir les mises à
    // jour de statut / position du livreur en temps réel.
    socket.on('order:watch', (orderId) => {
      socket.join(`order:${orderId}`);
    });
    socket.on('order:unwatch', (orderId) => {
      socket.leave(`order:${orderId}`);
    });
    // Un membre du staff rejoint la room "staff" pour être notifié des
    // nouvelles commandes en direct pendant qu'il a l'app ouverte.
    socket.on('staff:join', () => {
      socket.join('staff');
    });
  });
}

function getIo() {
  if (!ioInstance) throw new Error('Socket.io non initialisé');
  return ioInstance;
}

/** Diffuse la commande mise à jour à tous les clients qui la regardent. */
function emitOrderUpdate(orderId, order) {
  getIo().to(`order:${orderId}`).emit('order:update', order);
}

/** Notifie l'équipe qu'une nouvelle commande vient d'arriver. */
function emitNewOrderToStaff(order) {
  getIo().to('staff').emit('order:new', order);
}

module.exports = { initSocket, getIo, emitOrderUpdate, emitNewOrderToStaff };
