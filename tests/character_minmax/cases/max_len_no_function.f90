program p
print *,kind(max(f(),"x")),len(max(f(),"x"))
contains
character(2) function f()
integer::i
i=0
f=repeat("a",1/i)
end function
end program
