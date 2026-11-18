program p
implicit none
character(2)::a(2,2),b(3)
a=reshape(pack(['aa','bb','cc'],[.true.,.false.,.true.],vector=['ww','xx','yy','zz']), &
[2,2],order=[2,1])
print *,a(1,1),' ',a(2,1),' ',a(1,2),' ',a(2,2)
b=pack(reshape(['aa','bb','cc','dd'],[2,2],order=[2,1]), &
reshape([.true.,.false.,.true.,.true.],[2,2],order=[2,1]))
print *,b(1),' ',b(2),' ',b(3)
print *,kind(reshape(pack(['aa'],.false.),[0]))
end program
