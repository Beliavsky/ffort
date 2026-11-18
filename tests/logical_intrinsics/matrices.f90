program p
implicit none
logical :: x(-1:0,3:5)
integer :: d
x(:,3)=[.true.,.false.]
x(:,4)=[.true.,.true.]
x(:,5)=[.false.,.false.]
print *,all(x),any(x),count(x)
print *,all(x,1),any(x,1),count(x,1)
print *,all(x,2),any(x,2),count(x,2)
d=2
print *,count(kind=8,dim=d,mask=x),kind(count(x,d,8))
print *,count(x(0:-1:-1,5:3:-1),1),count(x(0:-1:-1,5:3:-1),2)
print *,count(count(x,1)>0)
end program
