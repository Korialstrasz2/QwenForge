import { create } from "zustand";

type ForgeState = {
  selectedProjectId?: number;
  selectedJobId?: number;
  setSelectedProjectId: (id?: number) => void;
  setSelectedJobId: (id?: number) => void;
};

export const useForgeStore = create<ForgeState>((set) => ({
  selectedProjectId: undefined,
  selectedJobId: undefined,
  setSelectedProjectId: (id) => set({ selectedProjectId: id }),
  setSelectedJobId: (id) => set({ selectedJobId: id }),
}));
