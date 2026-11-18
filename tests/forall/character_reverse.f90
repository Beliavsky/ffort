program p
implicit none
integer::i
character(3)::a(3)
a=["one","two","six"]
forall(i=1:3) a(i)=a(4-i)
print "(3a3)",a
end program
