import * as functions from 'firebase-functions/v1';

export const onTaskUpdate = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const afterData = change.after.data();
    functions.logger.info(`Task ${context.params.taskId} updated to status: ${afterData.status}`);
  });
