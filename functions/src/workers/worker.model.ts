export interface WorkerTask {
  id: string;
  workerUid: string;
  reportId: string;
  status: 'assigned' | 'in_progress' | 'completed' | 'cancelled';
  updatedAt: Date;
}
