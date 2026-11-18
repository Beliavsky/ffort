module m
contains
subroutine test_compress(words,factors,values)
character(*),intent(in)::words(:)
integer,intent(out)::factors(:)
character(*),allocatable,intent(out)::values(:)
integer::i,n,nfac,imatch
n = size(words)
if (size(factors) /= n) error stop "in compress, need size(words) == size(factors)"
if (n < 1) then
   allocate (values(0))
   return
end if
allocate (values(n))
values(1) = words(1)
factors(1) = 1
nfac = 1
do i=2,n
   imatch = findloc(values(:nfac),words(i),dim=1)
   if (imatch == 0) then
      nfac = nfac + 1
      factors(i) = nfac
      values(nfac) = words(i)
   else
      factors(i) = imatch
   end if
end do
values = values(:nfac)
end subroutine
end module
program p
use m
character(3)::words(6)=["one","two","one","tri","two","one"]
character(3),allocatable::values(:)
integer::factors(6)
call test_compress(words,factors,values)
print *,factors,values
call test_compress(words(:0),factors(:0),values)
print *,size(values)
end program
