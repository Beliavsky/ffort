program p
implicit none
integer::i
character(3)::a(2,2)
a=reshape(["one","two","six","ten"],[2,2])
forall(i=1:2) a(:,i)=a(:,3-i)
print "(4a3)",a
end program
