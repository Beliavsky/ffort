program p
implicit none
logical :: x(-2:2)
x=[.true.,.false.,.true.,.true.,.false.]
print *,all(x),any(x),count(x),count(x,dim=1),count(kind=8,mask=x)
print *,all(mask=x),any(dim=1,mask=x),kind(count(x,kind=8))
print *,all(x(2:-2:-1)),any(x(-1:2:2)),count(x(0:2))
end program
