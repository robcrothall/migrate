/* Puzzle */
do r = 0 to 9;
  do b = 0 to 9;
    do y = 0 to 9;
      do g = 0 to 9;
         l1 = 1000*r + 100*b + 10*g + b;
         l2 = 1000*b + 100*y + 10*b + r;
         l3 = 1000*y + 100*b + 10*r + g;
         If l1 + l2 = l3 then say 'r=' r 'b=' b 'g=' g 'y=' y 'Add';
         If l1 - l2 = l3 then say 'r=' r 'b=' b 'g=' g 'y=' y 'Subtract';
      end;
    end;
  end;
end;
