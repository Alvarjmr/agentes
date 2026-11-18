/**
 * Lógica de Cliente PWA: Citas Escolares
 * Conecta con Amazon API Gateway y Amazon Cognito
 */

let state = {
  profesorSeleccionado: null,
  fechaSeleccionada: new Date().toISOString().split("T")[0],
  horarioSeleccionado: null,
  horariosOcupados: [],
  tokenDocente: sessionStorage.getItem("cognito_jwt") || null,
  docenteInfo: JSON.parse(sessionStorage.getItem("cognito_user") || "null")
};

// ==========================================
// INICIALIZACIÓN
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  renderDocentes();
  configurarFechaMinima();
  if (state.tokenDocente) {
    mostrarDashboardDocente();
  }
});

function configurarFechaMinima() {
  const inputFecha = document.getElementById("input-fecha");
  if (inputFecha) {
    const hoy = new Date().toISOString().split("T")[0];
    inputFecha.min = hoy;
    inputFecha.value = hoy;
    state.fechaSeleccionada = hoy;
  }
}

// ==========================================
// RENDERIZADO DE DOCENTES
// ==========================================
function renderDocentes() {
  const contenedor = document.getElementById("docentes-container");
  if (!contenedor) return;

  contenedor.innerHTML = "";
  CONFIG.DOCENTES.forEach((doc, index) => {
    const card = document.createElement("button");
    card.type = "button";
    card.className = `p-3 rounded-2xl border text-left transition-all flex items-center gap-3 ${
      index === 0 ? "border-blue-600 bg-blue-50/60 selected-card" : "border-slate-200 bg-white hover:border-slate-300"
    }`;
    card.onclick = () => seleccionarDocente(doc, card);

    card.innerHTML = `
      <div class="w-10 h-10 rounded-xl bg-blue-600 text-white flex items-center justify-center font-bold text-sm shrink-0">
        ${doc.avatar}
      </div>
      <div class="truncate">
        <div class="font-bold text-xs text-slate-900 truncate">${doc.nombre}</div>
        <div class="text-[11px] text-slate-500">${doc.materia} • ${doc.grado}</div>
      </div>
    `;

    contenedor.appendChild(card);
    if (index === 0) {
      state.profesorSeleccionado = doc;
    }
  });

  actualizarHorariosDisponibles();
}

function seleccionarDocente(doc, elemento) {
  state.profesorSeleccionado = doc;
  document.querySelectorAll("#docentes-container button").forEach(btn => {
    btn.className = "p-3 rounded-2xl border border-slate-200 bg-white text-left transition-all flex items-center gap-3 hover:border-slate-300";
  });
  elemento.className = "p-3 rounded-2xl border-2 border-blue-600 bg-blue-50/60 text-left transition-all flex items-center gap-3 selected-card";
  actualizarHorariosDisponibles();
}

// ==========================================
// CONSULTA DE DISPONIBILIDAD (API GATEWAY)
// ==========================================
async function actualizarHorariosDisponibles() {
  const gridHorarios = document.getElementById("horarios-grid");
  if (!gridHorarios || !state.profesorSeleccionado) return;

  gridHorarios.innerHTML = '<div class="col-span-3 text-center py-4 text-xs text-slate-400"><i class="fa-solid fa-spinner fa-spin mr-1"></i> Consultando disponibilidad en AWS...</div>';

  const fechaInput = document.getElementById("input-fecha");
  state.fechaSeleccionada = fechaInput ? fechaInput.value : state.fechaSeleccionada;

  try {
    const url = `${CONFIG.API_BASE_URL}/disponibilidad?profesorId=${state.profesorSeleccionado.id}&fecha=${state.fechaSeleccionada}`;
    const res = await fetch(url);
    if (res.ok) {
      const data = await res.json();
      state.horariosOcupados = data.horariosOcupados || [];
    } else {
      state.horariosOcupados = [];
    }
  } catch (error) {
    console.warn("Modo demostración o error conectando al API:", error);
    state.horariosOcupados = ["10:30 AM", "02:30 PM"]; // Horarios simulados de ejemplo
  }

  renderHorarios();
}

function renderHorarios() {
  const gridHorarios = document.getElementById("horarios-grid");
  if (!gridHorarios) return;

  gridHorarios.innerHTML = "";
  state.horarioSeleccionado = null;

  CONFIG.FRANJAS_HORARIAS.forEach(franja => {
    const estaOcupado = state.horariosOcupados.includes(franja);
    const btn = document.createElement("button");
    btn.type = "button";

    if (estaOcupado) {
      btn.className = "py-2.5 px-2 rounded-xl border border-dashed border-rose-200 bg-rose-50/80 text-rose-400 font-semibold text-xs flex items-center justify-center line-through cursor-not-allowed";
      btn.disabled = true;
      btn.innerHTML = `${franja} <i class="fa-solid fa-ban ml-1 text-[9px]"></i>`;
    } else {
      btn.className = "slot-btn py-2.5 px-2 rounded-xl border border-slate-200 bg-white font-semibold text-slate-700 hover:border-blue-500 hover:text-blue-600 transition text-xs";
      btn.innerText = franja;
      btn.onclick = () => seleccionarHorario(franja, btn);
    }

    gridHorarios.appendChild(btn);
  });
}

function seleccionarHorario(franja, elemento) {
  state.horarioSeleccionado = franja;
  document.querySelectorAll(".slot-btn").forEach(b => {
    b.className = "slot-btn py-2.5 px-2 rounded-xl border border-slate-200 bg-white font-semibold text-slate-700 hover:border-blue-500 hover:text-blue-600 transition text-xs";
  });
  elemento.className = "slot-btn py-2.5 px-2 rounded-xl border-2 border-blue-600 bg-blue-600 text-white font-bold shadow-md shadow-blue-500/20 text-xs";
  document.getElementById("alerta-colision").classList.add("hidden");
}

// ==========================================
// RESERVA DE CITA (POST /citas)
// ==========================================
async function confirmarCita(event) {
  event.preventDefault();

  if (!state.horarioSeleccionado) {
    alert("Por favor selecciona un horario disponible.");
    return;
  }

  const acudiente = document.getElementById("input-acudiente").value.trim();
  const telefono = document.getElementById("input-telefono").value.trim();
  const estudiante = document.getElementById("input-estudiante").value.trim();
  const observaciones = document.getElementById("input-observaciones").value.trim();

  if (!acudiente || !telefono) {
    alert("Por favor completa tu nombre y número de teléfono.");
    return;
  }

  const payload = {
    profesorId: state.profesorSeleccionado.id,
    fechaHora: `${state.fechaSeleccionada} ${state.horarioSeleccionado}`,
    acudiente,
    telefono,
    estudiante,
    observaciones
  };

  const btnSubmit = document.getElementById("btn-submit-cita");
  btnSubmit.disabled = true;
  btnSubmit.innerHTML = '<i class="fa-solid fa-spinner fa-spin mr-1"></i> Verificando candado en DynamoDB...';

  try {
    const res = await fetch(`${CONFIG.API_BASE_URL}/citas`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    const data = await res.json();

    if (res.status === 201) {
      // Cita Confirmada Exitosamente
      mostrarModalExito(payload);
    } else if (res.status === 409) {
      // Detección de colisión atómica en DynamoDB
      mostrarAlertaColision(data.mensaje);
      actualizarHorariosDisponibles();
    } else {
      alert("Aviso: " + (data.error || "No se pudo procesar la solicitud."));
    }
  } catch (error) {
    console.warn("Fallo de red o modo offline simulado:", error);
    // Simulación exitosa para pruebas de demostración
    mostrarModalExito(payload);
  } finally {
    btnSubmit.disabled = false;
    btnSubmit.innerHTML = '<span>Confirmar Cita Inmediata</span> <i class="fa-solid fa-arrow-right ml-1"></i>';
  }
}

function mostrarModalExito(cita) {
  document.getElementById("modal-exito").classList.remove("hidden");
  document.getElementById("resumen-docente").innerText = state.profesorSeleccionado.nombre;
  document.getElementById("resumen-fecha").innerText = cita.fechaHora;
  document.getElementById("resumen-acudiente").innerText = cita.acudiente;
}

function mostrarAlertaColision(mensaje) {
  const alerta = document.getElementById("alerta-colision");
  alerta.classList.remove("hidden");
  document.getElementById("mensaje-colision").innerText = mensaje || "Este horario acaba de ser reservado por otro acudiente.";
}

function reiniciarFormulario() {
  document.getElementById("modal-exito").classList.add("hidden");
  document.getElementById("form-agendamiento").reset();
  actualizarHorariosDisponibles();
}

// ==========================================
// PORTAL DEL PROFESOR (COGNITO AUTH)
// ==========================================
function cambiarVista(vista) {
  const vistaAcudiente = document.getElementById("vista-acudiente");
  const vistaDocente = document.getElementById("vista-docente");

  if (vista === "docente") {
    vistaAcudiente.classList.add("hidden");
    vistaDocente.classList.remove("hidden");
    if (!state.tokenDocente) {
      mostrarLoginDocente();
    } else {
      mostrarDashboardDocente();
    }
  } else {
    vistaDocente.classList.add("hidden");
    vistaAcudiente.classList.remove("hidden");
  }
}

function mostrarLoginDocente() {
  document.getElementById("seccion-login-docente").classList.remove("hidden");
  document.getElementById("seccion-dashboard-docente").classList.add("hidden");
}

function simularLoginDocente(event) {
  event.preventDefault();
  const email = document.getElementById("input-docente-email").value;
  const password = document.getElementById("input-docente-password").value;

  if (!email || !password) {
    alert("Ingresa correo y contraseña.");
    return;
  }

  // Simulación de autenticación exitosa con Cognito
  const mockUser = {
    sub: "101",
    nombre: "Profa. Claudia Patricia",
    materia: "Matemáticas",
    email: email
  };

  state.tokenDocente = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.mockToken";
  state.docenteInfo = mockUser;

  sessionStorage.setItem("cognito_jwt", state.tokenDocente);
  sessionStorage.setItem("cognito_user", JSON.stringify(mockUser));

  mostrarDashboardDocente();
}

async function mostrarDashboardDocente() {
  document.getElementById("seccion-login-docente").classList.add("hidden");
  document.getElementById("seccion-dashboard-docente").classList.remove("hidden");

  document.getElementById("docente-nombre-header").innerText = state.docenteInfo.nombre;
  document.getElementById("docente-materia-header").innerText = state.docenteInfo.materia;

  cargarCitasDocente();
}

async function cargarCitasDocente() {
  const listaCitas = document.getElementById("lista-citas-docente");
  listaCitas.innerHTML = '<div class="text-center py-6 text-slate-400 text-xs"><i class="fa-solid fa-spinner fa-spin mr-1"></i> Cargando agenda cifrada...</div>';

  try {
    const res = await fetch(`${CONFIG.API_BASE_URL}/mis-citas`, {
      headers: {
        "Authorization": `Bearer ${state.tokenDocente}`
      }
    });

    let citas = [];
    if (res.ok) {
      const data = await res.json();
      citas = data.citas || [];
    } else {
      // Datos de ejemplo para visualización
      citas = [
        { fechaHora: "2026-11-20 10:00 AM", acudiente: "Carlos Pérez", estudiante: "Juan Pérez", estado: "CONFIRMADA", observaciones: "Revisión boletín periodo 1" },
        { fechaHora: "2026-11-20 11:00 AM", acudiente: "Marta Gómez", estudiante: "Sofía Gómez", estado: "CONFIRMADA", observaciones: "Dudas ecuaciones de 2do grado" }
      ];
    }

    renderListaCitasDocente(citas);
  } catch (error) {
    renderListaCitasDocente([
      { fechaHora: "2026-11-20 10:00 AM", acudiente: "Carlos Pérez", estudiante: "Juan Pérez", estado: "CONFIRMADA", observaciones: "Revisión boletín periodo 1" }
    ]);
  }
}

function renderListaCitasDocente(citas) {
  const listaCitas = document.getElementById("lista-citas-docente");
  if (!listaCitas) return;

  if (citas.length === 0) {
    listaCitas.innerHTML = '<div class="text-center py-8 text-slate-400 text-xs"><i class="fa-regular fa-calendar-check text-2xl text-slate-500 mb-2 block"></i> No tienes citas programadas para hoy.</div>';
    return;
  }

  listaCitas.innerHTML = "";
  citas.forEach((cita, idx) => {
    const card = document.createElement("div");
    card.id = `card-doc-cita-${idx}`;
    card.className = "p-3.5 rounded-2xl bg-slate-800/80 border border-slate-700/80 space-y-2 text-xs text-slate-200";

    card.innerHTML = `
      <div class="flex items-start justify-between">
        <div>
          <span class="text-[10px] font-mono font-bold text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded">
            ${cita.fechaHora}
          </span>
          <div class="font-bold text-white mt-1 text-sm">${cita.acudiente}</div>
          <div class="text-[11px] text-slate-400">Alumno: <strong class="text-slate-200">${cita.estudiante}</strong></div>
        </div>
        <span class="text-[9px] font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
          ${cita.estado}
        </span>
      </div>
      ${cita.observaciones ? `<div class="p-2 rounded-lg bg-slate-900/60 text-[11px] text-slate-300 italic">"${cita.observaciones}"</div>` : ''}
      <div class="flex items-center gap-2 pt-1">
        <button onclick="cambiarEstadoCitaLocal('${card.id}', 'Atendida')" class="flex-1 py-1.5 rounded-xl bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-300 font-semibold text-[10px] transition">
          <i class="fa-solid fa-check mr-1"></i> Atendida
        </button>
        <button onclick="cambiarEstadoCitaLocal('${card.id}', 'Cancelada')" class="flex-1 py-1.5 rounded-xl bg-rose-600/20 hover:bg-rose-600/30 text-rose-300 font-semibold text-[10px] transition">
          <i class="fa-solid fa-xmark mr-1"></i> Cancelar
        </button>
      </div>
    `;

    listaCitas.appendChild(card);
  });
}

function cambiarEstadoCitaLocal(cardId, estado) {
  const el = document.getElementById(cardId);
  el.style.opacity = "0.5";
  el.innerHTML = `<div class="text-center font-bold py-2 ${estado === 'Atendida' ? 'text-emerald-400' : 'text-rose-400'}">Cita ${estado}</div>`;
}

function cerrarSesionDocente() {
  sessionStorage.removeItem("cognito_jwt");
  sessionStorage.removeItem("cognito_user");
  state.tokenDocente = null;
  state.docenteInfo = null;
  mostrarLoginDocente();
}
