export type Job = {
  id: number;
  project_id: number;
  job_type: string;
  status: "queued" | "running" | "completed" | "failed" | "paused" | "cancelled";
  backend: string;
  model_id: string;
};

export type Project = {
  id: number;
  name: string;
  path: string;
  indexed: boolean;
  include_globs: string;
  exclude_globs: string;
};

export type Artifact = {
  id: number;
  job_id: number;
  artifact_type: string;
  title: string;
  content: string;
  path: string;
};

export type ModelProfile = {
  id: number;
  display_name: string;
  backend: string;
  model_id: string;
  endpoint: string;
};
