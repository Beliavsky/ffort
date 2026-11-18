module kinds_and_functions
implicit none
double precision,parameter::factor=2.0d0,values(2)=[1.0d0,3.0d0]
double precision,public::counter
interface twice
 module procedure twice_dp
end interface
contains
pure double precision function twice_dp(x) result(y)
 double precision,intent(in)::x
 y=factor*x
end function
double precision elemental function plus_one(x) result(y)
 double precision,intent(in)::x
 y=x+1.0d0
end function
end module
program declarations
use kinds_and_functions
implicit none
double precision bare, a(2)
double precision,target::target_values(2)
double precision,pointer::ptr(:)
double precision,allocatable::alloc(:)
bare=twice(3.0d0)
a=plus_one(values)
target_values=a
ptr=>target_values
allocate(alloc(2))
alloc=ptr
counter=bare
print *,kind(bare),kind(factor),int(counter),int(alloc)
deallocate(alloc)
end program
