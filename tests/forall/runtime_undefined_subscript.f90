program p
implicit none
integer::a(2),b(2),i
forall(i=1:2) a(b(i))=i
end program
