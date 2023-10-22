/*	George Atkinson
	CPSC1010 - Lab 6
	Sct. 002
*/

#include <stdio.h>

#define NUM_ACTIVITIES 5
#define MAX_LINE 20

int main(void) {

	char activities[NUM_ACTIVITIES][MAX_LINE];
	float weight, height, bmr, dailyCal, multiplier[NUM_ACTIVITIES] = { 0 };

	int i, age, sex;

	for (i = 0; i < NUM_ACTIVITIES; i++) {

		gets(activities[i]);
		scanf("%f\n", &multiplier[i]);

	}

	//freopen("/dev/tty", "rw", stdin);

	printf("\n\nAre you a boy or a girl? 1 for a boy,"
	" 2 for a girl: ");
	scanf("%d", &sex);

	printf("\nYour weight (pounds): ");
	scanf("%f", &weight);

	printf("Your height (inches): ");
	scanf("%f", &height);

	printf("Your age (years): ");
	scanf("%d", &age);

	// calculate BMR
	
	// convert to kg and cm
	weight /= 2.205;
	height *= 2.54;

	bmr = (10 * weight) + (6.25 * (float) height) - (5 * age);

	(sex == 1) ? (bmr += 5) : (bmr -= 161);

	printf("\n\nYour BMR (basal metabolic rate) is %.1f", bmr);
	printf("\n\nBMR represents the amount of calories you burn at rest."
	"\n\nTotal daily calories needed to maintain your current "
	"weight at a\nparticular activity levels is "
	"your BMR * that activity level value:\n\n");

	for (i = 0; i < NUM_ACTIVITIES; i++) {

		dailyCal = bmr * multiplier[i];
		printf("%.1f calories per day for %s\n", dailyCal, activities[i]);

	}

	return 0;

}
