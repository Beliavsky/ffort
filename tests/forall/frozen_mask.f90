program p
implicit none
integer::a(4),b(4),i
a=[1,2,3,4]
b=0
forall(i=1:4,a(i)>2)
a(i)=0
b(i)=a(i)+i
endforall
print *,a,b
end program
