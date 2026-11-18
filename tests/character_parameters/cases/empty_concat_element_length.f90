implicit none
character(*),parameter::a(0)=[character(3)::]//trim("a  ")
character(*),parameter::b(1)=reshape(a,[1],pad=["abcd"])
print '(a)',b//":"
end
