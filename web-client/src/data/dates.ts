export function getNextFourteenDays(): Date[] {
  const days: Date[] = [];
  const today = new Date();
  for (let i = 0; i < 14; i++) {
    days.push(new Date(today.getFullYear(), today.getMonth(), today.getDate() + i));
  }
  return days;
}

export function isPastSlot(day: Date, time: string): boolean {
  const [hour, minute] = time.split(':').map(Number);
  const slot = new Date(day.getFullYear(), day.getMonth(), day.getDate(), hour, minute, 0, 0);
  return slot.getTime() <= Date.now();
}
