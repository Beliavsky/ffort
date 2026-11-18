program main
implicit none
character(2)::a(2,2)
a=reshape(pack(['ab','cd','ef'],[.true.,.false.,.true.]),[2,2],pad=['xy'])
print *,pack(a,a/='xy')
end program
