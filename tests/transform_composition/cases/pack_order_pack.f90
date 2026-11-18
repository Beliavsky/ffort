program main
implicit none
integer::a(6)=[1,2,3,4,5,6]
print *,reshape(a,[2,3],order=pack([2,1,9],[.true.,.true.,.false.]))
end program
