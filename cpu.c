#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define BUF_SIZE 4096

typedef struct {
  unsigned long int user;
  unsigned long int nice;
  unsigned long int system;
  unsigned long int idle;
  unsigned long int iowait;
  unsigned long int irq;
  unsigned long int softirq;
  unsigned long int steal;
} cpu_usage;

cpu_usage readStats() {
  FILE* fp = fopen("/proc/stat", "r");
  
  cpu_usage usage;

  if (fp != NULL) {
    char buf[BUF_SIZE];

    while (fgets(buf, BUF_SIZE, fp)) {
      if (sscanf(buf, "cpu %lu %lu %lu %lu %lu %lu %lu %lu", 
        &usage.user, &usage.nice, &usage.system, &usage.idle, &usage.iowait, &usage.irq, &usage.softirq, &usage.steal)) {
        break;
      }
    }
  }
  
  fclose(fp);
  
  //printf("usage: %lu %lu %lu %lu %lu %lu %lu %lu\n", 
  //  usage.user, usage.nice, usage.system, usage.idle, usage.iowait, usage.irq, usage.softirq, usage.steal);
  
  return usage;
}

// count from composite value until we reach the intr line
int countCores() {
  FILE* fp = fopen("/proc/stat" ,"r");
    int num = -1;
  if (fp != NULL) {
    char buf[BUF_SIZE];

    while (fgets(buf, BUF_SIZE, fp)) {
      // dont care about composite value
      if (strstr(buf, "cpu ") != NULL) {
        continue;
      }
      num += 1;

      if (strstr(buf, "intr") != NULL) {
        fclose(fp);
        return num;
      }
    }
  }
  
  return num;
}

double calculateUsage(cpu_usage u1, cpu_usage u2, int numCores) {
  unsigned long int totalUsage1 = u1.user + u1.nice + u1.system + u1.irq + u1.softirq + u1.steal;
  unsigned long int totalUsage2 = u2.user + u2.nice + u2.system + u2.irq + u2.softirq + u2.steal;
  
  unsigned long int totalIdle1 = u1.idle + u1.iowait;
  unsigned long int totalIdle2 = u2.idle + u2.iowait;
  
  unsigned long int total1 = totalUsage1 + totalIdle1;
  unsigned long int total2 = totalUsage2 + totalIdle2;
  
  unsigned long int totald = total2 - total1;
  unsigned long int idled = totalIdle2 - totalIdle1;
  
  double result = (double) (totald - idled) / (double) totald;
  
  return result;
}

int main(void) {
  int numCores = countCores();
  // take a reading
  cpu_usage usage1 = readStats();
  
  // wait a second and take another
  sleep(1);
  cpu_usage usage2 = readStats();

  double usagePercent = calculateUsage(usage1, usage2, numCores) * 100;

  //printf("Usage: %.0f%%\n", usagePercent);
  printf("%0.2f%%\n", usagePercent);
}
