from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException

from app.core.config import get_settings
from app.core.network_policy import require_local_endpoint
from sqlmodel import Session, select

from app.db.session import get_session
from app.inference.adapters import build_adapter
from app.models.entities import Artifact, Job, ModelProfile, Project
from app.schemas.contracts import HealthResponse, JobCreate, ModelProfileCreate, ProjectCreate
from app.services.jobs import create_job
from app.workers.runner import run_job

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok", backend="api", queue="dramatiq", timestamp=datetime.utcnow())


@router.get("/inference/health")
async def inference_health(backend: str = "vllm"):
    adapter = build_adapter(backend)
    return await adapter.health()


@router.get("/inference/models")
async def inference_models(backend: str = "vllm"):
    adapter = build_adapter(backend)
    return {"data": await adapter.list_models()}


@router.post("/projects")
def add_project(payload: ProjectCreate, session: Session = Depends(get_session)):
    project = Project(**payload.model_dump())
    session.add(project)
    session.commit()
    session.refresh(project)
    return project


@router.get("/projects")
def get_projects(session: Session = Depends(get_session)):
    return session.exec(select(Project).order_by(Project.created_at.desc())).all()


@router.post("/models")
def add_model(payload: ModelProfileCreate, session: Session = Depends(get_session)):
    settings = get_settings()
    require_local_endpoint(payload.endpoint, all_local_mode=settings.all_local_mode)
    model = ModelProfile(**payload.model_dump())
    session.add(model)
    session.commit()
    session.refresh(model)
    return model


@router.get("/models")
def get_models(session: Session = Depends(get_session)):
    return session.exec(select(ModelProfile)).all()


@router.post("/jobs")
def enqueue_job(payload: JobCreate, session: Session = Depends(get_session)):
    project = session.get(Project, payload.project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    job = create_job(
        session,
        Job(
            project_id=payload.project_id,
            job_type=payload.job_type,
            backend=payload.backend,
            model_id=payload.model_id,
        ),
    )
    run_job.send(job.id, payload.job_type, project.name)
    return job


@router.get("/jobs")
def list_jobs(session: Session = Depends(get_session)):
    return session.exec(select(Job).order_by(Job.created_at.desc())).all()


@router.get("/jobs/{job_id}/artifacts")
def list_artifacts(job_id: int, session: Session = Depends(get_session)):
    return session.exec(select(Artifact).where(Artifact.job_id == job_id)).all()
