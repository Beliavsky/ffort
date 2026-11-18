! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
program original_combined_driver
use original_combinations
implicit none
call check(4,3)
call check(5,3)
call check(2,3)
contains
subroutine check(n,k)
integer,intent(in)::n,k
integer::a(choose(n,k),k),b(choose(n,k),k),comb(k)
integer::first_sum
comb=0
a=-7
call gen(1,n,k,comb,a,zero_icomb=.true.)
b=few_combinations(n,k)
if(any(a/=b)) error stop 1
first_sum=sum(a)
a=-7
call gen(1,n,k,comb,a)
print *,shape(b),first_sum,sum(a)
end subroutine
end program
