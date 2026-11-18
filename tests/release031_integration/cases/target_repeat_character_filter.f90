! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
character(3),target :: words(3)
character(6),target :: doubled(3)
logical,allocatable,target :: keep(:)
words=['ab ','cd ','ab ']
keep=[.true.,.false.,.true.]
doubled=expand(words)
print *,shape(doubled),len(doubled),shape(keep)
print *,findloc(doubled,repeat('ab ',2),mask=keep),findloc(doubled,repeat('ab ',2),mask=keep,back=.true.)
print '(a)',doubled(1)
print '(a)',doubled(2)
contains
function expand(x) result(y)
character(*),target,intent(in) :: x(:)
character(len=2*len(x(1))),target :: y(size(x))
integer :: i
do i=1,size(x)
 y(i)=repeat(ncopies=2_8,string=x(i))
end do
end function
end program
