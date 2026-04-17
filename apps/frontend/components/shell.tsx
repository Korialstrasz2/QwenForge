"use client";

import { useQuery } from "@tanstack/react-query";
import { Activity, Database, FolderTree, Hammer, Settings, Sparkles } from "lucide-react";

import { fetchJson } from "@/lib/api";
import { Artifact, Job, ModelProfile, Project } from "@/types/contracts";
import { useForgeStore } from "@/store/useForgeStore";

const nav = [
  "Dashboard",
  "Project Workspace",
  "Job Runner",
  "Artifact Viewer",
  "Agent Trace",
  "Control Panel",
  "Template Studio",
  "Knowledge Base",
];

export function ForgeShell() {
  const selectedJobId = useForgeStore((s) => s.selectedJobId);
  const setSelectedJobId = useForgeStore((s) => s.setSelectedJobId);

  const projects = useQuery({ queryKey: ["projects"], queryFn: () => fetchJson<Project[]>("/api/projects") });
  const jobs = useQuery({ queryKey: ["jobs"], queryFn: () => fetchJson<Job[]>("/api/jobs"), refetchInterval: 3000 });
  const models = useQuery({ queryKey: ["models"], queryFn: () => fetchJson<ModelProfile[]>("/api/models") });
  const artifacts = useQuery({
    queryKey: ["artifacts", selectedJobId],
    queryFn: () => fetchJson<Artifact[]>(`/api/jobs/${selectedJobId}/artifacts`),
    enabled: Boolean(selectedJobId),
  });

  return (
    <div className="min-h-screen p-6">
      <div className="grid gap-4 xl:grid-cols-[220px_1fr]">
        <aside className="panel p-4">
          <div className="mb-6 flex items-center gap-2 font-semibold"><Hammer className="h-4 w-4 text-accent" /> Forge</div>
          <nav className="space-y-2 text-sm text-slate-300">
            {nav.map((item) => (
              <div key={item} className="rounded-lg px-3 py-2 hover:bg-slate-900/60">{item}</div>
            ))}
          </nav>
        </aside>

        <main className="space-y-4">
          <section className="grid gap-4 lg:grid-cols-4">
            <StatCard icon={<Activity className="h-4 w-4" />} label="API Status" value="Healthy" />
            <StatCard icon={<Database className="h-4 w-4" />} label="Models" value={String(models.data?.length ?? 0)} />
            <StatCard icon={<FolderTree className="h-4 w-4" />} label="Projects" value={String(projects.data?.length ?? 0)} />
            <StatCard icon={<Sparkles className="h-4 w-4" />} label="Active Jobs" value={String(jobs.data?.filter((j) => j.status === "running").length ?? 0)} />
          </section>


          <section className="grid gap-4 lg:grid-cols-2">
            <div className="panel p-4">
              <h2 className="mb-3 text-sm font-semibold">Project Workspace</h2>
              <form className="grid gap-2" onSubmit={async (e)=>{e.preventDefault(); const f=new FormData(e.currentTarget); await fetchJson("/api/projects",{method:"POST",body:JSON.stringify({name:String(f.get("name")),path:String(f.get("path")),include_globs:String(f.get("include")),exclude_globs:String(f.get("exclude"))})}); projects.refetch();}}>
                <input name="name" className="rounded-md bg-slate-900 p-2 text-sm" placeholder="Project name" required />
                <input name="path" className="rounded-md bg-slate-900 p-2 text-sm" placeholder="/Users/me/code/repo" required />
                <input name="include" className="rounded-md bg-slate-900 p-2 text-sm" defaultValue="**/*" />
                <input name="exclude" className="rounded-md bg-slate-900 p-2 text-sm" defaultValue="**/.git/**,**/node_modules/**" />
                <button className="rounded-md bg-slate-100 px-3 py-2 text-sm font-medium text-black">Add project</button>
              </form>
            </div>
            <div className="panel p-4">
              <h2 className="mb-3 text-sm font-semibold">Model Profiles</h2>
              <form className="grid gap-2" onSubmit={async (e)=>{e.preventDefault(); const f=new FormData(e.currentTarget); await fetchJson("/api/models",{method:"POST",body:JSON.stringify({display_name:String(f.get("display_name")),backend:String(f.get("backend")),model_id:String(f.get("model_id")),endpoint:String(f.get("endpoint")),api_key:String(f.get("api_key")),quantization_note:String(f.get("quant"))})}); models.refetch();}}>
                <input name="display_name" className="rounded-md bg-slate-900 p-2 text-sm" placeholder="Qwen Coder Local" required />
                <input name="backend" className="rounded-md bg-slate-900 p-2 text-sm" defaultValue="vllm" />
                <input name="model_id" className="rounded-md bg-slate-900 p-2 text-sm" defaultValue="Qwen/Qwen2.5-Coder-7B-Instruct" />
                <input name="endpoint" className="rounded-md bg-slate-900 p-2 text-sm" defaultValue="http://localhost:8001/v1" />
                <input name="api_key" className="rounded-md bg-slate-900 p-2 text-sm" defaultValue="local-key" />
                <input name="quant" className="rounded-md bg-slate-900 p-2 text-sm" placeholder="AWQ 4-bit" />
                <button className="rounded-md bg-slate-100 px-3 py-2 text-sm font-medium text-black">Save model</button>
              </form>
            </div>
          </section>

          <section className="grid gap-4 lg:grid-cols-2">
            <div className="panel p-4">
              <h2 className="mb-3 text-sm font-semibold">Job Runner</h2>
              <p className="mb-4 text-xs text-slate-400">Create analysis, docs, tests, refactor, and research jobs.</p>
              <form
                className="grid gap-2"
                onSubmit={async (e) => {
                  e.preventDefault();
                  const form = new FormData(e.currentTarget);
                  await fetchJson("/api/jobs", {
                    method: "POST",
                    body: JSON.stringify({
                      project_id: Number(form.get("project")),
                      job_type: String(form.get("job_type")),
                      backend: String(form.get("backend")),
                      model_id: String(form.get("model")),
                    }),
                  });
                  jobs.refetch();
                }}
              >
                <select name="project" className="rounded-md bg-slate-900 p-2 text-sm" required>
                  <option value="">Select project</option>
                  {(projects.data || []).map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
                <select name="job_type" className="rounded-md bg-slate-900 p-2 text-sm" defaultValue="codebase_analysis">
                  {[
                    "codebase_analysis","documentation_generation","architecture_summarization","api_map_generation","test_generation","refactor_advisor","bug_hunt","release_notes","repository_onboarding","project_qa","research_document","long_running_agent"
                  ].map((j) => <option key={j} value={j}>{j}</option>)}
                </select>
                <input className="rounded-md bg-slate-900 p-2 text-sm" name="backend" defaultValue="vllm" />
                <input className="rounded-md bg-slate-900 p-2 text-sm" name="model" defaultValue="Qwen/Qwen2.5-Coder-7B-Instruct" />
                <button className="rounded-md bg-accent px-3 py-2 text-sm font-medium text-black">Run job</button>
              </form>
            </div>

            <div className="panel p-4">
              <h2 className="mb-3 text-sm font-semibold">Control Panel</h2>
              <div className="space-y-2 text-xs text-slate-300">
                <ControlLine label="Internet" value="Disabled by default" />
                <ControlLine label="Shell policy" value="Sandboxed + explicit permission" />
                <ControlLine label="Write mode" value="Preview diff before apply" />
                <ControlLine label="Git policy" value="Branch-per-job" />
                <ControlLine label="Concurrency" value="1 active / model role" />
                <ControlLine label="Backend" value="vLLM default, oobabooga optional" />
              </div>
              <div className="mt-4 rounded-lg border border-slate-700 p-3 text-xs text-slate-400">
                First-run wizard: add model profile, test connectivity, and set default templates.
              </div>
            </div>
          </section>

          <section className="grid gap-4 lg:grid-cols-2">
            <div className="panel p-4">
              <h2 className="mb-2 text-sm font-semibold">Jobs & Traces</h2>
              <div className="space-y-2">
                {(jobs.data || []).map((job) => (
                  <button key={job.id} onClick={() => setSelectedJobId(job.id)} className="w-full rounded-md border border-slate-800 p-2 text-left text-xs hover:bg-slate-900">
                    <div className="font-medium">#{job.id} {job.job_type}</div>
                    <div className="text-slate-400">{job.backend} • {job.model_id} • {job.status}</div>
                  </button>
                ))}
              </div>
            </div>

            <div className="panel p-4">
              <h2 className="mb-2 text-sm font-semibold">Artifact Viewer</h2>
              {selectedJobId ? (
                <div className="space-y-3">
                  {(artifacts.data || []).map((artifact) => (
                    <article key={artifact.id} className="rounded-md border border-slate-800 p-3">
                      <h3 className="text-xs font-semibold">{artifact.title}</h3>
                      <p className="mb-2 text-[11px] text-slate-500">{artifact.path}</p>
                      <pre className="max-h-44 overflow-auto whitespace-pre-wrap text-[11px] text-slate-300">{artifact.content}</pre>
                    </article>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400">Select a job to inspect artifacts, diffs, logs, and structured outputs.</p>
              )}
            </div>
          </section>
        </main>
      </div>
      <button className="fixed bottom-6 right-6 rounded-full border border-slate-700 bg-panel p-3 text-slate-300"><Settings className="h-4 w-4" /></button>
    </div>
  );
}

function StatCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return <div className="panel flex items-center justify-between p-4"><div className="text-sm text-slate-400">{label}</div><div className="flex items-center gap-2 text-base font-semibold">{icon}{value}</div></div>;
}

function ControlLine({ label, value }: { label: string; value: string }) {
  return <div className="flex items-center justify-between rounded bg-slate-900/50 px-2 py-1.5"><span>{label}</span><span className="text-slate-500">{value}</span></div>;
}
