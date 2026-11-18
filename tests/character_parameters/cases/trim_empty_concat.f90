implicit none
character(*),parameter::a(0)=[character(2)::]//trim("!  ")
character(*),parameter::b(0)=trim("?  ")//[character(2)::]
print *,size(a),size(b)
end
