! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
character(4) words(3)
character(5) labels(3)
logical,allocatable :: keep(:)
words=['ab  ','cd  ','ab  ']
keep=[.true.,.false.,.true.]
labels=decorate(words)
print *,shape(labels),len(labels),shape(keep)
print *,findloc(labels,'ab  !',mask=keep),findloc(labels,'ab  !',mask=keep,back=.true.)
print '(a5)',labels(1)
print '(a5)',labels(2)
contains
function decorate(x) result(y)
character(*),intent(in) :: x(:)
character(len=len(x(1))+1) y(size(x))
integer i
do i=1,size(x)
 y(i)=x(i)//'!'
end do
end function
end program
