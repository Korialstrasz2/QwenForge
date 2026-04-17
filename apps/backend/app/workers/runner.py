import dramatiq
from dramatiq.brokers.redis import RedisBroker
from sqlmodel import Session

from app.core.config import get_settings
from app.db.session import engine
from app.models.entities import JobStatus
from app.services.jobs import append_artifact, build_default_job_artifacts, mark_job_status

settings = get_settings()
redis_broker = RedisBroker(url=settings.redis_url)
dramatiq.set_broker(redis_broker)


@dramatiq.actor
def run_job(job_id: int, job_type: str, project_name: str):
    with Session(engine) as session:
        mark_job_status(session, job_id, JobStatus.running)
        artifacts = build_default_job_artifacts(job_type, project_name)
        for artifact_type, title, content in artifacts:
            append_artifact(session, job_id, artifact_type, title, content)
        mark_job_status(session, job_id, JobStatus.completed)
