program demo
implicit none
integer :: vals(4)
vals=[1,-2,3,-4]
print *,reduce(vals,3)
contains
pure recursive integer function reduce(x,n) result(y)
integer,intent(in)::x(:),n
integer::work(size(x))
work=x
where(work<0) work=-work
if(n==0) then
 y=sum(work)
else
 y=reduce(work,n-1)+scan('abc','b')+verify('aaa','a')
end if
end function
end program
