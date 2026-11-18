program p
implicit none
integer,parameter :: n=count([.true.,.false.,.true.],kind=8)
logical,parameter :: yes=all([.true.,.true.])
real(8),parameter :: z=dble(n)
integer,parameter :: k=merge(8,4,yes)
real(8) :: x
x=z
print *,n,yes,x,k,any([.false.,yes])
end program
