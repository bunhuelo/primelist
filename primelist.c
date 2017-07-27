#include <stdio.h>

unsigned long primecache[100000];
unsigned long primesfound;

/* returns 1 if number is odd and 0 if not */
inline unsigned int isOdd(unsigned long number)
{
    if(number%2) return 1;
    return 0;
}

/* returns 1 if number is prime and 0 if not */
unsigned int isPrime(unsigned long number)
{
    unsigned long count;
    
    count=number/2;
    if(count%2==0) ++count; /* make count odd */
    do
    {
        if(number%count == 0) return 0;
        count-=2; /* should become count-=2 after assuring count is odd */
    } while(count > 2);
    return 1;
}

void itoafast(unsigned long number, char* destination, unsigned int length, unsigned int radix)
{
    /* currently not used as we use printf */
}

int main(int argc, char** argv)
{
    unsigned int number;
    
    primesfound=0;
    primecache[primesfound++]=2;
    primecache[primesfound++]=3;
        
    number=5;
    do
    {
        if(isPrime(number))  primecache[primesfound++]=number;
        number+=2;
    } while (number<100000);
    
    number=0;
    do
    {
        printf("%lu\n", primecache[number]);
        ++number;
    } while (number<primesfound);
    
    return 0;
}

