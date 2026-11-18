program p
implicit none
integer::a(2,3)
a=reshape([1,2,3,4,5,6],[2,3],order=pack([2,1,3],[.true.,.true.,.false.]))
print *,a
end program
