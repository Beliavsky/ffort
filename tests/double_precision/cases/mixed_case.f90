module kinds_and_functions
implicit none
DoUbLePrEcIsIoN,parameter::factor=2.0d0,values(2)=[1.0d0,3.0d0]
DoUbLePrEcIsIoN,public::counter
interface twice
 module procedure twice_dp
end interface
contains
pure DoUbLePrEcIsIoN function twice_dp(x) result(y)
 DoUbLePrEcIsIoN,intent(in)::x
 y=factor*x
end function
DoUbLePrEcIsIoN elemental function plus_one(x) result(y)
 DoUbLePrEcIsIoN,intent(in)::x
 y=x+1.0d0
end function
end module
program declarations
use kinds_and_functions
implicit none
DoUbLePrEcIsIoN bare, a(2)
DoUbLePrEcIsIoN,target::target_values(2)
DoUbLePrEcIsIoN,pointer::ptr(:)
DoUbLePrEcIsIoN,allocatable::alloc(:)
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
